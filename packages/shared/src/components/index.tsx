import React from 'react'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: 'primary' | 'secondary' | 'outline'
    size?: 'sm' | 'md' | 'lg'
    loading?: boolean
}

export const Button: React.FC<ButtonProps> = ({
    children,
    variant = 'primary',
    size = 'md',
    loading = false,
    className = '',
    disabled,
    ...props
}) => {
    const baseStyles = 'font-medium rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed'

    const variantStyles = {
        primary: 'bg-black text-white hover:bg-gray-800',
        secondary: 'bg-gray-200 text-black hover:bg-gray-300',
        outline: 'border-2 border-black text-black hover:bg-black hover:text-white'
    }

    const sizeStyles = {
        sm: 'px-3 py-1.5 text-sm',
        md: 'px-4 py-2 text-base',
        lg: 'px-6 py-3 text-lg'
    }

    return (
        <button
            className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]} ${className}`}
            disabled={disabled || loading}
            {...props}
        >
            {loading ? (
                <span className="flex items-center gap-2">
                    <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Loading...
                </span>
            ) : (
                children
            )}
        </button>
    )
}

interface CardProps {
    children: React.ReactNode
    className?: string
}

export const Card: React.FC<CardProps> = ({ children, className = '' }) => {
    return (
        <div className={`bg-white border-2 border-black rounded-lg p-6 ${className}`}>
            {children}
        </div>
    )
}

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
    label?: string
    error?: string
}

export const Input: React.FC<InputProps> = ({
    label,
    error,
    className = '',
    ...props
}) => {
    return (
        <div className="w-full">
            {label && (
                <label className="block text-sm font-medium text-gray-900 mb-1">
                    {label}
                </label>
            )}
            <input
                className={`w-full px-4 py-2 border-2 border-black rounded-lg focus:outline-none focus:ring-2 focus:ring-black ${error ? 'border-red-500' : ''
                    } ${className}`}
                {...props}
            />
            {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
        </div>
    )
}

interface TextAreaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
    label?: string
    error?: string
}

export const TextArea: React.FC<TextAreaProps> = ({
    label,
    error,
    className = '',
    ...props
}) => {
    return (
        <div className="w-full">
            {label && (
                <label className="block text-sm font-medium text-gray-900 mb-1">
                    {label}
                </label>
            )}
            <textarea
                className={`w-full px-4 py-2 border-2 border-black rounded-lg focus:outline-none focus:ring-2 focus:ring-black ${error ? 'border-red-500' : ''
                    } ${className}`}
                {...props}
            />
            {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
        </div>
    )
}

interface BadgeProps {
    children: React.ReactNode
    variant?: 'default' | 'success' | 'warning' | 'error'
}

export const Badge: React.FC<BadgeProps> = ({ children, variant = 'default' }) => {
    const variantStyles = {
        default: 'bg-gray-200 text-gray-900',
        success: 'bg-green-100 text-green-800 border-green-800',
        warning: 'bg-yellow-100 text-yellow-800 border-yellow-800',
        error: 'bg-red-100 text-red-800 border-red-800'
    }

    return (
        <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border ${variantStyles[variant]}`}>
            {children}
        </span>
    )
}
